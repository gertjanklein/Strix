FROM containers.intersystems.com/intersystems/iris-community:2022.1.0.199.0

# Copy script that loads the files
COPY build.script build.script

# Run it
RUN iris start IRIS \
  && iris session IRIS < build.script \
  && iris stop IRIS quietly
