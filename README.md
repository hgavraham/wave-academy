# Wave Academy Final Project - Part 1
## Static Web Page - High Availability

To use this repo there are some prerequisites that you need to perform
Create tow (2) env variable on you local machine 
```
> linux
export AWS_ACCESS_KEY="xxxxxxxxxx"
export AWS_SECRET_KEY="xxxxxxxxxxxxxxxxxxxx"
```


1. Pull the current git by:
```
git pull https://github.com/hgavraham/wave-academy.git
```
2. Checkout to part1
```
git checkout part1
```
3. From the current directory you did the pull nun 
``` 
terraform init
```
4. After you run the `terraform init` you can deploy the system by
```
terraform apply -auto-approve
```

