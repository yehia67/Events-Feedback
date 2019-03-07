from flask import Flask
app = Flask(__name__)


@app.route('/')
def index():
    return 'Index Page'

@app.route('/yarab')
def yarab():
    return 'bsmlaa'

if __name__ == '__main__':
	app.debug = True
	app.run()
	app.run(debug = True)
