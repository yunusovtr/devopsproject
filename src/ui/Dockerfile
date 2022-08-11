FROM python:3.6-alpine
ADD . /
RUN pip install -r requirements.txt -r requirements-test.txt

WORKDIR /
ENV FLASK_APP=ui.py

CMD ["sh", "-c", "cd ui && FLASK_APP=ui.py gunicorn ui:app -b 0.0.0.0"]

#CMD [ "gunicorn", "ui:app", "-b 0.0.0.0" ]