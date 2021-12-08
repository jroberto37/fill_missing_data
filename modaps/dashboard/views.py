from django.http import HttpResponse

from django.shortcuts import render

from .models import Zone
from .models import Product

# Create your views here.
def home(request):
    return  render(request, 'home.html', {'b':12})
