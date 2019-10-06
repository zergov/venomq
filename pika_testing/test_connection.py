import pika

# Replication of the first tutorial on the rabbitmq website.
# https://www.rabbitmq.com/tutorials/tutorial-one-python.html
connection = pika.BlockingConnection()
channel = connection.channel()
channel.queue_declare(queue='hello')
