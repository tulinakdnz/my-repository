from flask import Flask
app = Flask(__name__)

@app.route('/')
def hello():
    return "<h1>Hello World</h1>"

@app.route('/second')
def second():
    return "<h2>This is second page</h2>"

@app.route('/third/subthird')
def third():
    return "This is the subpage of the third page"

@app.route('/forth/<string:id>')
def forth(id):
    return f'This is page id {id}'

if __name__ == '__main__':
    app.run(debug=False)