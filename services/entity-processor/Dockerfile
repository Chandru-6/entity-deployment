FROM eclipse-temurin:17-jre
WORKDIR /app
COPY services/entity-processor/target/*.jar app.jar
EXPOSE 8082
ENTRYPOINT ["java","-jar","/app/app.jar"]

