import boto3
import json
import os
from datetime import date
import cloudwatch_markdown as md
from datetime import datetime


## comments add instance type/ add image sha/ compare with other opensource image


cloudwatch = boto3.client('cloudwatch', region_name='us-west-2')
# parameters we need to configure
# parameters = {'docker_image':"",'num_nodes':"",}

# # variable to store all value of experiment parameter
# experiment_para_value = set()

num_nodes=0
instance_type=""

# # the namespace to send metrics data to
# namespace="experiment"
# the dashboard to display all experiments result
dashboard = "dlc_benchmark"


# generate experiment results row and send metrics data
def generate_table_rows(metrics_dir_path):
    '''
    Input: str: path to the directory containing all .metrics.json results files for a benchmark job.
    Read all the .metrics.json files and generate table rows (lists) containing relevant information for
    each result. Output as a list of lists. 
    '''
    experiment_table_rows = []
    global docker_image, num_nodes, image_sha, instance_type
    
    # the header rows 
    files = [f for f in os.listdir(metrics_dir_path) if os.path.isfile(os.path.join(metrics_dir_path, f)) and f.endswith('.metrics.json')]
    for file in files:
        with open(os.path.join(metrics_dir_path, file), 'r') as f:
            data = json.load(f)

            # add model name to header row
            experiment_row = [
                data['model']['name'],
                round(data['model']['perf_metrics']['throughput']),
                data['model']['perf_metrics']['measure']
                data['image']
                data['image_sha']
            ]
           
            experiment_table_rows.append(experiment_row)

            if not num_nodes:
                num_nodes=data["num_nodes"]
            if not instance_type:
                instance_type=data["instance_type"]
                

    # sort all rows to keep the same model together               
    experiment_table_rows.sort(key=lambda x: (x[1], x[0]))
    return experiment_table_rows


# update dashboard with benchmark result text widget
def update_dashboard(job_name, table_rows):
    
    response = cloudwatch.get_dashboard(
        DashboardName=dashboard
    )
    dashboard_body = json.loads(response['DashboardBody'])
  
    
    result_headers = ["Model Name", "Throughput", "Measure", "Image", "ImageDigest"]
    
    # generate markdown used in text widget
    markdown = md.dumps(
        md.h1(job_name) + \
        [""] + \
        md.h3("Benchmark Setting") + \
        md.table(
            # . just for table pretty 
            headers=["Instance","Nodes"],
            rows = [[instance_type, num_nodes]]
        ) + \
        [""] + \
        md.h3("Results") + \
        md.table(
            headers=result_headers,
            rows=table_rows
        )
    )
    # move current all text widgets down
    for widget in dashboard_body['widgets']:
        # if widget['y'] != 0 and widget['type']=="text":
        #     widget['x'] = (widget['x'] + 8) % 24
        widget['y'] = widget['y'] + 10

    # the new text widget used to display this result   
    new_text_widget = {
        "height": 10,
        "width": 24,
        "y": 14,
        "x": 0,
        "type": "text",
        "properties": {
            "markdown": markdown
        }
    }
    
    
    # add text widget to 
    # the top of all text widget and discard previous text widgets if the num
    # of exepriment text widgets > 15
    dashboard_body['widgets'] = dashboard_body['widgets'][:1] + \
    [new_text_widget] + dashboard_body['widgets'][1:21]
    dashboard_body = json.dumps(dashboard_body)
    cloudwatch.put_dashboard(
        DashboardName=dashboard,
        DashboardBody=dashboard_body
    )


def main(metrics_dir_path, job_name):
    table_rows = generate_table_rows(metrics_dir_path)
    update_dashboard(job_name, table_rows)


if __name__ == '__main__':
    import argparse
    parser = argparse.ArgumentParser(description='read benchmark results and push to CloudWatch')
    parser.add_argument('--metrics_dir_path', metavar='PATH', required=True, help='the path to the directory where .metrics.json files reside')
    parser.add_argument('--job_name', metavar='NAME', required=True, help='the name of the job being reported')
    args = parser.parse_args()
    main(args.metrics_dir_path, args.job_name)