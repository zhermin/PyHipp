import boto3

region = "ap-southeast-1"
instances = [
    "i-00b873f20e23b902b",
]
ec2 = boto3.client("ec2", region_name=region)


def lambda_handler(event, context):
    ec2.terminate_instances(InstanceIds=instances)
    print("terminated your instances: " + str(instances))
