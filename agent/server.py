import os, socket
from pathlib import Path
import requests
from fastapi import FastAPI
from pydantic import BaseModel
import json
import asyncio
from loguru import logger


ROOT=Path(__file__).resolve().parents[1]
ENV=ROOT/'config'/'agent.env'
SKILLS=ROOT/'skills'
REGISTER=ROOT/'config'/'register.json'

if ENV.exists():
    for line in ENV.read_text().splitlines():
        if line and not line.startswith('#') and '=' in line:
            k,v=line.split('=',1); os.environ.setdefault(k.strip(),v.strip())
ROLE=os.getenv('ROLE','worker')

# Load mapping of workers
if ROLE!='worker':
    with open(REGISTER, 'r') as f:
        register_workers = json.load(f)
    logger.info(f"Workers registered: {register_workers}")
    local_workers = [(f'http://{i.get("url")}:8001', i.get("model"), i.get("machine"))
                     for i in register_workers.get("workers")
                     ]
MODEL_FILE=os.getenv('MODEL_FILE','unknown')
PORT=int(os.getenv('PORT','8001'))
LOCAL_WORKER=f"http://{os.getenv('LLAMA_HOST','127.0.0.1')}:{os.getenv('LLAMA_PORT','11434')}"
MODEL_NAME=os.getenv('MODEL_NAME','qwen2.5:1.5b')
app=FastAPI(title='Distributed Agent')

def read_file(filepath):
    with open(filepath, 'r') as f:
        return f.read()

async def call_workers(prompt:str, endpoint:str, action:str):
        r=requests.post(f'{endpoint}/task',
                        json={'task':{
                                'action':action,
                                'request':prompt
                                },
                              'context':''
                              }
                        )
        return r.json()

async def local_call(system_prompt:str, prompt:str,):
    r=requests.post(f'{LOCAL_WORKER}/v1/chat/completions',
                    json={'model':MODEL_NAME,
                          'messages':[{'role':'system',
                                       'content':system_prompt
                                      },
                                      {'role':'user',
                                       'content':prompt
                                      }
                                     ],
                          'temperature':0.2,
                          'max_tokens':1000
                          }
                    ,timeout=300)
    r.raise_for_status()
    return {
            'result':r.json()['choices'][0]['message']['content']
            }

class Task(BaseModel):
    task:str
    context:str=''
    action:str
    
@app.get('/health')
def health():
    return {'status':'online'
           ,'hostname':socket.gethostname()
           ,'role':ROLE
           ,'model':MODEL_FILE
           ,'runtime':'ollama'
           }
           
@app.post('/task')
async def task(req:Task):
    skill = SKILLS/req.action/'SKILL.md' 
    system_prompt=f'''You are an agent in a distributed AI system. Your role is {ROLE}. You will provide what user requests using by usign the following SKILL: {skill}'''
    prompt = f'''This is the user request answer only what is asked you can use the context to improve your answer. User: {req.task}  context: {req.context} '''
    workers_result = ""
    if ROLE != "worker":
        workers_result = [await call_workers(
                                      prompt,
                                      endpoint,
                                      req.action
                                      ) for endpoint, machine, model in local_workers
                   ]
    logger.info(f"Workers executed result: {workers_result}")
    initial_worker = await local_call(system_prompt, prompt)
    logger.info(f"Initial worker: {initial_worker}")    
    return {'workers':workers_result,
            'local_executor': initial_worker
            }
