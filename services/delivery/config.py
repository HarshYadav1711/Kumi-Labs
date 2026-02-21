from pydantic_settings import BaseSettings


class Settings(BaseSettings):
    mongodb_url: str = "mongodb://localhost:27017"
    mongodb_db: str = "delivery_db"

    class Config:
        env_prefix = "DELIVERY_"
        env_file = ".env"


settings = Settings()
