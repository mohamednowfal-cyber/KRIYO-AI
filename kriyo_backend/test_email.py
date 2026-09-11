import os
import smtplib
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart
from dotenv import load_dotenv

load_dotenv()

sender = os.getenv("SMTP_USERNAME")
password = os.getenv("SMTP_PASSWORD")
if password:
    password = password.replace(" ", "").strip()

receiver = "muhmednowfal@gmail.com"

msg = MIMEMultipart()
msg["From"] = sender
msg["To"] = receiver
msg["Subject"] = "KRIYO SMTP Test"

msg.attach(MIMEText(
    "This is a test email from the KRIYO backend.",
    "plain"
))

try:
    with smtplib.SMTP("smtp.gmail.com", 587, timeout=15) as server:
        server.starttls()
        server.login(sender, password)
        server.sendmail(sender, receiver, msg.as_string())

    print("EMAIL SENT SUCCESSFULLY")

except Exception as e:
    print("EMAIL FAILED:")
    print(repr(e))
