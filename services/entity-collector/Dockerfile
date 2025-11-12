FROM eclipse-temurin:17-jre
WORKDIR /app
COPY services/entity-collector/target/*.jar app.jar
EXPOSE 8081
ENTRYPOINT ["java","-jar","/app/app.jar"]
