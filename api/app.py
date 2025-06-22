from fastapi import FastAPI
from config import Base, engine
from routers import usuario

app = FastAPI()

Base.metadata.create_all(bind=engine)

#app.include_router(usuario.router, prefix="/usuarios")
