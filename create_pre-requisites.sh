git clone git@github.com:browserstack/percy-demo.git
mkdir logs
cd percy-demo
npm install
git branch update-button-base
git checkout update-button-base
cp changed_assets/css/spark.css assets/css/spark.css
cp changed_assets/scss/01-settings/_colors.scss assets/scss/01-settings/_colors.scss
git add assets
git commit -m "Update button style changes"
git checkout main