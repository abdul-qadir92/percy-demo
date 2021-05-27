# demo-dashboard

A demo application to showcase the power of Percy!

Note: this repository is private and should not be shared because it is based on the spark-bootstrap-theme, which is closed source. Full license is here: https://themes.getbootstrap.com/licenses/ .

## Requirements

- NodeJS (https://nodejs.org/)
- Hub (https://hub.github.com/)

## Installation

1. Open your console.
2. Navigate to the root folder.
3. Run `npm install` to install the testing dependencies.

## Create a new demo PR

Run:
```bash
./create-demo-pr.sh
```

## Development

1. Run `npm start` while developing. This will automatically start a dev server at http://localhost:8080/ and detect scss file changes. It is not necessary to run this to run the tests.

## Known issues

- `Node Sass could not find a binding for you current environment: *` while running `npm start`.
Run `npm rebuild node-sass --force` in your console to rebuild node-sass for your current environment.
