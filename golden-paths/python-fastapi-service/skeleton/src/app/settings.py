from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_prefix="APP_")

    log_level: str = "info"
    port: int = 8080
    # OpenAPI docs stay off outside dev — an unauthenticated schema endpoint is an
    # information-disclosure surface in shared environments.
    expose_docs: bool = False


settings = Settings()
