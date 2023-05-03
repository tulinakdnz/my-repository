# Import Flask and render_template modules.
from flask import Flask, render_template

# Create an object named `app` from imported Flask module.
app = Flask(__name__)

# - Create a function named `head` which sends number `number1` and `number2` 
# variables to the `index.html`. Use these variables into the `index.html` file. 
# Assign a URL route the `head` function with decorator `@app.route('/')`.
@app.route('/')
def head():
    return render_template('index.html', number1=10, number2=20)


@app.route('/number1/<string:num1>')
def num1(num1):
    return render_template('index.html', number1=num1, number2=100)

# - Create an `body.html` file under templates folder.

# - Create a function named `number` which sends number `num1` and `num2` and sum of them to the `index.html`. Use these variables into the `body.html` file. Assign a URL route the `number` function with decorator `@app.route('/sum')`.

# - run the application in debug mode

if __name__ == '__main__':
    app.run(debug=True)