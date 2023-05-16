# 1password: inject secrets from 1password to root env file
dumpenv:
  op inject -i ./env.example -o .env
