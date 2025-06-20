FROM python:3.14.0b3-alpine3.21 
WORKDIR /app
COPY requirements.txt requirements.txt
RUN pip install -r requirements.txt
COPY . .
EXPOSE 80
CMD python ./app/phonebook-app.py
