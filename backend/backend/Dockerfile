FROM python:3.12-slim

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    NOVA_ENV=production \
    NOVA_DB_PATH=/data/nova.sqlite3

WORKDIR /app

COPY requirements.txt ./
RUN pip install --no-cache-dir -r requirements.txt \
    && useradd --system --uid 10001 --create-home nova \
    && mkdir -p /data \
    && chown -R nova:nova /app /data

COPY --chown=nova:nova app.py admin.html ./

USER nova

EXPOSE 8000

CMD ["uvicorn", "app:app", "--host", "0.0.0.0", "--port", "8000"]
