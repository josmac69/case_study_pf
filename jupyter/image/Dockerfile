# Use the Miniconda3 base image
FROM continuumio/miniconda3

# Set the working directory to /app
WORKDIR /app

# Copy the requirements.txt file to the container
COPY requirements.txt .

# Install the required libraries using conda
# based on: https://www.technologyscout.net/2017/11/how-to-install-dependencies-from-a-requirements-txt-file-with-conda/
RUN while read requirement; do echo "installing $requirement"; conda install --yes $requirement; done < requirements.txt

# Start Jupyter notebook
CMD ["jupyter", "notebook", "--ip=0.0.0.0", "--no-browser", "--allow-root"]