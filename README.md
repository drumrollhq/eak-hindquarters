# eak-hindquarters
server-side gubbins that powers https://api.eraseallkittens.com/

## Getting Started
1. Install [vagrant](https://www.vagrantup.com/)
2. Clone the EAK vagrant repo: `$ git clone https://github.com/drumrollhq/eak-vagrant.git && cd eak-vagrant`
3. Start vagrant: `$ vagrant up`. This will set up a VM with [mongo](https://www.mongodb.org/) and [postgres](http://www.postgresql.org/), plus a postgres database and user
4. Clone eak-hindquarters: `$ git clone https://github.com/drumrollhq/eak-hindquarters.git && cd eak-hindquarters`
5. Install dependencies: `$ npm install`
6. EAK-hindquarters uses [bunyan](https://github.com/trentm/node-bunyan) for logging, which outputs JSON.
   To convert this to a more human-friendly format, install the `bunyan` command line tool: `$ npm install -g bunyan`
7. Run hindquarters: `$ npm start` (or, with bunyan: `$ npm start | bunyan`)
8. Celebrate or something? WOOOO
