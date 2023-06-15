# 1password: inject secrets from 1password to root env file
dumpenv:
  op inject -i ./env.example -o .env

# setup litestream config yaml file
conf:
  litestream replicate -config etc/litestream.yaml
