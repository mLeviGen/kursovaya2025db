
# PostgreSQL Database Project

## Overview
This project contains the PostgreSQL database setup and configuration for the kursovaya2025 application.

## Getting Started

### Prerequisites
- PostgreSQL 12 or higher
- psql command-line tool

# 🧀 Cheese Factory Information System (Database)

Database for the "Cheese Factory" information system. Developed as a Software Engineering course project.

The project demonstrates a **Security-centric architecture**: business logic, security rules, and access control are implemented directly at the PostgreSQL DBMS level.

## 🚀 Architectural Features

* **Data Isolation**: Direct access to tables is restricted for all application users (except the super-admin). All interactions occur via protected Stored Procedures and Views.
* **Security Schemas**:
    * `private`: Stores raw data tables. Access is strictly denied to external roles.
    * `admin`: Functions for user management and analytical views.
    * `workers`: Business logic for employees (Technologist, Inspector).
    * **authorized**: Business logic for clients (Order processing).
    * `public`: Data types (ENUMs), utility functions, and authentication.
* **Role-Based Access Control (RBAC)**: Every system user (`client`, `employee`) maps to a real PostgreSQL role. **Row-Level Security** is emulated via context functions (e.g., `get_my_id()`).
* **Automation**: Triggers automatically calculate prices, expiration dates (`best_before`), and batch statuses.
* **Normalization**: The database structure adheres to the **3rd Normal Form (3NF)**.

## 🛠 Installation and Setup

The project is fully containerized using Docker.

### Prerequisites
* Docker & Docker Compose

### How to Run
1.  Clone the repository.
2.  Navigate to the project root.
3.  Build and start the containers:

```bash
docker-compose up --build
```
### Stop and Clean
To stop the containers and remove the database volume (reset data):
```bash
docker-compose down -v
```

## Connection Details
The database is exposed on port 5433 (to avoid conflicts with local Postgres instances).

| Parameter | Value                             |
|-----------|-----------------------------------|
| Host      | localhost                         |
| Port      | 5433                              |
| Database  | cheese_db                         |
| User      | postgres (for administration)     |
| Password  | See `.env` file (default: `root`) |


## Project Structure
```
db-posgresql
/
├── docker-compose.yml      # Docker container configuration
├── migrate.sh              # Migration execution script
├── .env                    # Environment variables
└── db-postgresql/sql/      # SQL Source files
    ├── _init/              # Database initialization
    ├── _structure/         # Roles, Schemas, Grants
    ├── public/             # Types (ENUMS), Auth, Utils
    ├── private/            # Tables (DDL), Triggers
    ├── admin/              # User management, Analytics Views
    ├── workers/            # Employee logic
    ├── authorized/         # Client logic
    └── seed/               # Seed data
```

## Contributing
When making changes to the database schema:
1. Create migrations in the `migrations/` directory
2. Test locally before pushing
3. Submit a pull request to the `main` branch

## License
See LICENSE file for details
