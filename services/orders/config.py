from pydantic_settings import BaseSettings


class Settings(BaseSettings):
    mongodb_url: str = "mongodb://localhost:27017"
    mongodb_db: str = "orders_db"

    class Config:
        env_prefix = "ORDERS_"
        env_file = ".env"


settings = Settings()
