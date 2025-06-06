FROM python:3.13

RUN pip install --upgrade pip
COPY requirements.txt /app/requirements.txt
RUN pip install --require-hashes -r /app/requirements.txt

COPY *.py /app/

ENTRYPOINT [ "/usr/local/bin/python3", "/app/sample.py" ]

