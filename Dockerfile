FROM public.ecr.aws/docker/library/python:3.9
ARG PROJECT_ROOT

# プロジェクト配下に.venvを作成する
ENV PIPENV_VENV_IN_PROJECT true

RUN apt-get update && pip3 install pipenv