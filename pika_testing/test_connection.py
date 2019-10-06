import pika

connection = pika.BlockingConnection()
channel = connection.channel()
