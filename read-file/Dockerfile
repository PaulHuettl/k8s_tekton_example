FROM python:3
WORKDIR /app
COPY . .
RUN pip install -r requirements.txt
RUN pip install -e .
CMD ["python3", "read_cli/main.py"]