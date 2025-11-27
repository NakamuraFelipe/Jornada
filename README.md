📱 Projeto Jornada — Mobile + Backend

Este projeto consiste em um aplicativo mobile desenvolvido em Flutter, integrado a um backend em Python (Flask).
Abaixo segue o guia completo para executar o projeto tanto no celular quanto no servidor local.

📌 Pré-requisitos
🔧 Ferramentas necessárias

Flutter SDK

Android SDK + ferramentas de plataforma

JDK (Java Development Kit) — recomendado Java 11+

Python 3.8+ (backend)

Git

Celular Android com:

Depuração USB ativada

Conectado na mesma rede Wi-Fi que o backend

🧩 Instalação do projeto
1️⃣ Clonar o repositório
git clone <url-do-repositorio>
cd Jornada

📱 Como rodar o aplicativo Flutter
2️⃣ Configurar ambiente Flutter/Android

Verifique se o Flutter reconhece seu ambiente:

flutter doctor


Aceite licenças do Android:

flutter doctor --android-licenses


Ative Depuração USB no celular e conecte via cabo.

Teste se o celular foi reconhecido:

flutter devices

3️⃣ Instalar dependências do Flutter

Dentro da pasta do app (onde está o pubspec.yaml):

flutter pub get

4️⃣ Executar o aplicativo

Com o celular conectado:

flutter run

🖥️ Como rodar o backend (Flask)
5️⃣ Acessar o backend
cd Jornada/back_end

6️⃣ Ativar o ambiente virtual (venv)
Windows
python -m venv venv
venv\Scripts\activate

Linux/MacOS
python3 -m venv venv
source venv/bin/activate

7️⃣ Instalar dependências do backend
pip install -r requirements.txt

8️⃣ Iniciar o servidor Flask
python app.py


Agora o backend estará rodando em:

http://SEU-IP-LOCAL:5000

🌐 Conectando o App Mobile ao Backend

Para o Flutter se comunicar com o backend:

Conecte o computador e o celular na mesma rede Wi-Fi.

Pegue o IP da máquina onde o backend está rodando.

Windows
ipconfig

Mac/Linux
ifconfig


Anote o IPv4, por exemplo:

192.168.0.15

3️⃣ Ajuste o IP no código Flutter

Procure por:

Uri.parse('http://ALGUM-IP-AQUI:5000')


Troque pelo IP da sua rede:

Uri.parse('http://192.168.0.15:5000')


⚠️ Lembre-se:
Troque todos os locais no código que utilizam o backend.

📦 Dependências usadas no projeto
📱 Flutter (Dart)

Com base nos imports utilizados:

dependencies:
  flutter:
    sdk: flutter
  fl_chart:
  http:
  shared_preferences:
  intl:


Imports usados:

import 'dart:convert';
import 'dart:math';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

🖥️ Backend (Python Flask)

Dependências com base no projeto:

Flask
flask-cors
passlib
pymysql
argon2-cffi
PyJWT


Imports usados:

from flask import Flask, Blueprint, request, jsonify, session
from flask_cors import CORS
from passlib.hash import argon2
from argon2 import PasswordHasher
import pymysql
import base64
import jwt
import datetime
import os

🗄️ Conexão com Banco de Dados

Se estiver usando MySQL (ou outro), edite as credenciais no arquivo:

Jornada/back_end/database.py


Ajuste:

host

usuário

senha

database

🛠️ Problemas comuns (e soluções)
🚫 Celular não aparece no flutter devices

Ative Depuração USB

Use um cabo de boa qualidade

Instale drivers USB do fabricante (Windows)

🌐 App não conecta ao backend

Backend deve rodar com:

python app.py


Certifique-se que o app está apontando para o IP correto

Confirme que o firewall não está bloqueando a porta 5000

Celular e PC na mesma rede Wi-Fi

🔥 Erros de CORS

No backend, certifique-se que possui:

CORS(app)

✔️ Projeto pronto para uso

Agora você pode rodar o backend localmente, iniciar o aplicativo Flutter no celular e testar toda a comunicação entre eles.
