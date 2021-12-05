# Wave Academy Final Project - Part 1
## Static Web Page - High Availability

To use this repo there are some prerequisites that you need to perform
Create tow (2) env variable on you local machine 
```
export AWS_ACCESS_KEY="xxxxxxxxxx"
export AWS_SECRET_KEY="xxxxxxxxxxxxxxxxxxxx"
```


1. Clone the current git by:
```
git clone https://github.com/hgavraham/wave-academy.git
```
2. After the Clone change Directody to "wave-academy"
```
cd wave-academy/
```
3. Checkout to part1
```
git checkout part1
```
4. From the current directory you did the pull nun 
``` 
terraform init
```
5. After you run the `terraform init` you can deploy the system by
```
terraform apply -auto-approve
```
6. When the deploy is finished please open the link that you get from the output `ToDoList_WebApp_DNS_name`
```
Example
ToDoList_WebApp_DNS_name = "http://wafp1-alb-xxxxxxxxxx.us-east-1.elb.amazonaws.com/"
```
## Part 1 Video Demo



https://user-images.githubusercontent.com/48091445/144739998-75783295-dbae-4b1e-b243-8a30fcc4a9a2.mp4

