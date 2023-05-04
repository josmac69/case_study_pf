# Use the Miniconda3 base image
FROM continuumio/miniconda3

# Set the working directory to /app
WORKDIR /app

# Copy the requirements.txt file to the container
COPY requirements.txt .

# Install the required libraries
# based on: https://www.technologyscout.net/2017/11/how-to-install-dependencies-from-a-requirements-txt-file-with-conda/
RUN apt-get update && \
    apt-get install -y libpq-dev gcc && \
    pip install --verbose -r /app/requirements.txt

# Start Jupyter notebook
CMD ["jupyter", "notebook", "--ip=0.0.0.0", "--no-browser", "--allow-root"]