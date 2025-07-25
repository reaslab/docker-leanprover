# docker-leanprover

A Docker-based environment for building and testing [Lean 4](https://leanprover.github.io/) projects.

## Features

- Automated download and setup of Lean 4 toolchains (stable, nightly, or custom).
- Necessary dependencies for running Mathlib based projects.
- User and group management for safe file permissions.
- Node.js included for Lean 4 InfoView.

## Usage

### Using Prebuilt Images

Prebuilt images for various Lean toolchains are available on [GHCR](https://github.com/reaslab/docker-leanprover/pkgs/container/docker-leanprover). You can pull and run them directly:

```sh
docker pull ghcr.io/reaslab/docker-leanprover:<toolchain>
docker run --rm -it ghcr.io/reaslab/docker-leanprover:<toolchain>
```

Replace `<toolchain>` with e.g. `v4.15.0`.

### Available Tags

| Toolchain Version           | Image Tag            |
| --------------------------- | -------------------- |
| Latest stable release       | `stable`             |
| Release version v4.xx.x     | `v4.xx.x`            |
| Latest nightly build        | `nightly`            |
| Nightly built at YYYY-MM-DD | `nightly-yyyy-mm-dd` |

For detailed version tag listings, refer to the Lean repository releases:

- Releases: <https://github.com/leanprover/lean4/releases>
- Nightly: <https://github.com/leanprover/lean4-nightly/releases>

### Environment Variables

The [`entrypoint.sh`](./entrypoint.sh) script supports these environment variables:

- `USER`, `GROUP`: Set the username/group inside the container (default: `lean`).
- `UID`, `GID`: Set the user/group IDs (default: 1000).
- `XDG_CACHE_HOME`: Set a custom cache directory (default: `/var/cache/lean`), will be automatically created and changed to writable permissions for configured user.

Example:

```sh
docker run -e USER=myuser -e UID=1234 ghcr.io/mnixry/docker-leanprover:v4.15.0 /bin/bash
```

## License

This project is licensed under the MIT License. See the [LICENSE](./LICENSE) file for details.

    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
    IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
    FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
    AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
    LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
    OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
    SOFTWARE.
