# jetbrains-indexer

Generate & package JetBrains [shared indexes](https://www.jetbrains.com/help/idea/shared-indexes.html) with a Docker container.

Shared indexes are often hosted on a CDN and used by IDEs to speed up loading (indexing) time for JetBrains IDEs (IntelliJ IDEA, PyCharm, GoLand, etc). Blog post: <https://coder.com/blog/faster-jetbrains-ides-with-shared-indexes>

## Basic usage

1.  Generate indexes for your project

    ```sh
    cd your-project/

    docker run --rm \
        -v ./:/var/myprojectname \
        -v ./indexes:/shared-index \
        -e IDEA_PROJECT_DIR=/var/myprojectname \
        -e INDEXES_CDN_URL=https://my-index.s3.ap-southeast-2.amazonaws.com/myprojectname \
        ghcr.io/aaronflorey/indexer:phpstorm-2024.3
    ```

2.  Upload indexes to CDN (or test locally)

    ```sh
    aws s3 sync "./indexes/server/" s3://my-index/myprojectname/ --delete
    ```

    > this URL must be the same as INDEXES_CDN_URL in step 1.

3.  Add `intellij.yaml` to your project if you don't have one

    ```yaml
    sharedIndex:
        project:
            - url: https://my-index.s3.ap-southeast-2.amazonaws.com/myprojectname/project/myprojectname
        consents:
            - kind: project
            decision: allowed
    ```

4.  Open your IDE and test (use `File → Invalidate Caches` to load indexes for the first time again)

## IDE support

By default, this project indexes version 2024.3 of your IDE. Specify the IDE name by using the appropriate tag (e.g `aaronflorey/indexer:[ide-name]-2024.3`). 

If an IDE/version is not on DockerHub, we recommend you manually pulling and building the image yourself using [these build arguments](https://github.com/aaronflorey/jetbrains-indexer/blob/master/image/Dockerfile#L3-L9).

## Example Github Actions

This can be used to setup your project, generate indexes, and upload to s3 every night at midnight.

```yaml
name: Indexes

on:
  schedule:
    - cron: '0 14 * * *'

concurrency:
  group: indexes
  cancel-in-progress: true

jobs:
  indexes:
    name: Generate Indexes
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 1
          ref: staging

     - name: Setup PHP
       uses: shivammathur/setup-php@v2
       with:
         php-version: 8.4
         tools: composer:v2

     - uses: ramsey/composer-install@v3

     - uses: actions/setup-node@v4
       with:
         cache: npm
         node-version: 22

     - name: Install NPM packages
       run: npm ci --prefer-offline --no-audit

      - name: run tool
        run: |
          docker run --rm \
            -v ./:/var/myprojectname \
            -v ./indexes:/shared-index \
            -e IDEA_PROJECT_DIR=/var/myprojectname \
            -e INDEXES_CDN_URL=https://my-indexes.s3.ap-southeast-2.amazonaws.com/myprojectname \
            ghcr.io/aaronflorey/indexer:phpstorm-2024.3

      - name: Upload
        run: aws s3 sync "./indexes/server/" s3://my-indexes/myprojectname/ --delete
        env:
          AWS_ACCESS_KEY_ID: ${{ secrets.INDEXES_AWS_KEY }}
          AWS_SECRET_ACCESS_KEY: ${{ secrets.INDEXES_AWS_SECRET }}
          AWS_DEFAULT_REGION: ap-southeast-2
```
