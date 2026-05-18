import http.server
import socketserver
import subprocess
import os

PORT = 8009

class Handler(http.server.SimpleHTTPRequestHandler):
    def do_GET(self):
        if self.path == "/":
            self.send_response(200)
            self.send_header("Content-type", "text/html")
            self.end_headers()

            self.wfile.write(b"""
            <html>
            <body>
                <h2>Simple Build Server</h2>
                <form method="POST" action="/build">
                    <button type="submit">Run build.sh</button>
                </form>
                <p><a href="/files">Browse files</a></p>
            </body>
            </html>
            """)
        elif self.path.startswith("/files"):
            self.path = self.path.replace("/files", "", 1) or "/"
            super().do_GET()
        else:
            super().do_GET()

    def do_POST(self):
        if self.path == "/build":
            try:
                subprocess.Popen(["make"])
                msg = "build.sh started"
            except Exception as e:
                msg = f"Error: {e}"

            self.send_response(200)
            self.send_header("Content-type", "text/html")
            self.end_headers()
            self.wfile.write(f"""
            <html>
            <body>
                <p>{msg}</p>
                <a href="/">Back</a>
            </body>
            </html>
            """.encode())

with socketserver.TCPServer(("0.0.0.0", PORT), Handler) as httpd:
    print(f"Serving at http://localhost:{PORT}")
    httpd.serve_forever()
