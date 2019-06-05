# Data Driven Testing

We can implement data driven tests by providing a function pointer as a data-provider. The function returns a value-set of data and you can iterate the same test over the returned data-set.

In this example we have implemented a simple hello service which gets user input and provide a response. 

We have the main test function 'testHelloServiceResponse' which accepts a single parameter. We have defined our data provider as helloServiceDataProvider. 

```
@test:Config {
    dataProvider: "helloServiceDataProvider"
}
```

We pass the data to the test cases as below. 
```
function helloServiceDataProvider() returns (string[][]) {
    return [["John"], [" "]];
}
```

Running these tests will result in running two test cases. 