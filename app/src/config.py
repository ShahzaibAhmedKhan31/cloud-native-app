from pydantic_settings import BaseSettings


class Settings(BaseSettings):
    # Database settings
    db_host: str = "localhost"
    db_port: int = 5432
    db_name: str = "itemsdb"
    db_user: str = "appuser"
    db_password: str = "apppassword"

    # App settings
    app_env: str = "local"
    app_version: str = "0.1.0"

    @property
    def database_url(self) -> str:
        return (
            f"postgresql://{self.db_user}:{self.db_password}"
            f"@{self.db_host}:{self.db_port}/{self.db_name}"
        )

    class Config:
        env_file = ".env"


settings = Settings()