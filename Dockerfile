# Stage 1: Build the application
FROM maven:3.8.6-eclipse-temurin-17-alpine AS build
WORKDIR /app

# Copia el archivo pom.xml y descarga las dependencias sin compilar la aplicación
COPY pom.xml .
RUN mvn dependency:go-offline

# Copia el código fuente y compila la aplicación
COPY src ./src
RUN mvn clean package -DskipTests

# Stage 2: Run the application
FROM openjdk:17-jdk-slim
WORKDIR /app

# Copia el archivo JAR compilado desde la etapa de build
COPY --from=build /app/target/*.jar app.jar

# Exponer el puerto 8000 para la aplicación
EXPOSE 8000

# Comando para ejecutar la aplicación
ENTRYPOINT ["java", "-jar", "app.jar"]

# Opcional: Agregar un HEALTHCHECK para monitorear la salud del contenedor
HEALTHCHECK --interval=30s --timeout=10s --start-period=30s --retries=3 CMD curl --fail http://localhost:8000/api/swagger-ui.html || exit 1