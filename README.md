# README
# Utah ABA Finder API
<h2>This Rails application manages the data provided for our Utah ABA Finder BE application, which provides endpoints for ABA provider information in the state of Utah that is linked to a frontend application.</h2>

## Table of Contents
- [Setup](#setup)
- [Links](#links)
- [Contributors](#contributors)


## Setup

These instructions will help you set up and run the project on your local machine for development and testing purposes.

### Prerequisites

Ensure you have the following software installed:

- Ruby 3.2.2
- Rails 7.1.3.4
- PostgreSQL

### Installing

Follow these steps to set up the development environment:

Fork and Clone the repository: 

    git clone git@github.com:utah-aba-finder/utah-aba-finder-api.git

Install dependencies by running this in the terminal:

    bundle install

Set up the database by running these commands in the terminal:

    rails db:create
    rails db:migrate
    rails db:seed

Run the server in the terminal:

    rails server

You can now access the API in your browser at http://localhost:3000.

## Related Links & Repositories
- [Utah ABA Finder API Repository](https://github.com/utah-aba-finder/utah-aba-finder-api)
- [Utah ABA Finder BE Repository](https://github.com/utah-aba-finder/utah_aba-finder_be)
- [Utah ABA Finder FE Repository](https://github.com/utah-aba-finder/utah-aba-finder-fe)
- [Deployed Applications in PRD](https://utahabalocator.com/)

## Contributors
- [Austin Carr Jones](https://github.com/austincarrjones)
- [Chee_Lee](https://github.com/cheeleertr)
- [Jordan Williamson](https://github.com/JWill06)
- [Kevin Nelson](https://github.com/kevinm23nelson)
- [Mel Langhoff](https://github.com/mel-langhoff)
- [Seong Kang](https://github.com/sanghoro)