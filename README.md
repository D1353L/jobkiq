# Jobkiq

[![CI](https://github.com/D1353L/jobkiq/actions/workflows/ci.yml/badge.svg?branch=master)](https://github.com/D1353L/jobkiq/actions/workflows/ci.yml)

Jobkiq is a lightweight background job processing library with tag-based concurrency control.

## Key features

- **Parallel processing**: Multiple workers can process jobs concurrently.
- **Ordered execution**: Jobs are executed in order based on their creation timestamp.
- **Tag-based concurrency**: Each specified tag is processed by only one worker at a time.
- **Efficient idle behavior**: Workers consume no CPU when there are no jobs to process.

## Usage

### CLI

Run worker:

```bash
exe/jobkiq worker --q optional_queue
```

Enqueue job:

```bash
exe/jobkiq perform_async TestJob tag1 tag2 --q optional_queue
```

### Docker Compose

Run workers:

```bash
docker compose up --scale worker=5
```

Enqueue job:

```bash
docker compose exec worker ruby exe/jobkiq perform_async TestJob tag1 tag2
```

## Contributing

Bug reports and pull requests are welcome on GitHub.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
