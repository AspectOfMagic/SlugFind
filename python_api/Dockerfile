FROM python:3

WORKDIR /server

COPY . .

RUN pip install flask

CMD [ "python", "./server.py" ]

EXPOSE 8090