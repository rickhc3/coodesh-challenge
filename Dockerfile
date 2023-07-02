# Dockerfile para o frontend
FROM node:16

# Configurar o diretório de trabalho
WORKDIR /app

# Instalar o Yarn
# RUN npm install -g yarn

# Instalar as dependências do frontend
COPY ./package.json .
# RUN yarn

# Copiar o código do frontend
COPY . .

ENV NUXT_HOST=0.0.0.0
ENV NUXT_PORT=7000

COPY ./run.sh /tmp

# Conceder permissões de execução ao arquivo run.sh
RUN chmod +x /tmp/run.sh

#CMD yarn dev
EXPOSE 7000

ENTRYPOINT ["/tmp/run.sh"]
