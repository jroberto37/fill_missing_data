from django.db import models

# Create your models here.
class Zone(models.Model):
    w = models.FloatField()
    n = models.FloatField()
    e = models.FloatField()
    s = models.FloatField()
    startdate = models.DateField()
    enddate = models.DateField()

class Product(models.Model):
    producto = models.CharField(max_length=20)   