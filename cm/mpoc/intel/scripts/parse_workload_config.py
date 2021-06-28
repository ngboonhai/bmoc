"""
Wrapper for mlperf benchmark
"""

from argparse import ArgumentParser
import json
import os
import sys
import copy


SCENARIOS = ("SingleStream", "Offline", "Server")
MODES = ("Performance", "Accuracy")
DEVICES = ("CPU",
                        "GPU",
                        "GPU.0",
                        "GPU.1",
                        "GPU.2",
                        "MULTI:CPU,GPU",
                        "MULTI:CPU,GPU.0",
                        "MULTI:CPU,GPU.1",
                        "MULTI:CPU,GPU.2",
                        "MULTI:GPU,CPU",
                        "MULTI:GPU.0,CPU",
                        "MULTI:GPU.1,CPU",
                        "MULTI:GPU.2,CPU",
                        "MULTI:GPU.0,GPU.1",
                        "MULTI:GPU.0,GPU.2",
                        "MULTI:GPU.1,GPU.0",
                        "MULTI:GPU.1,GPU.2",
                        "MULTI:GPU.2,GPU.0",
                        "MULTI:GPU.2,GPU.1",
                        )
                        
MODEL_NAMES = ("resnet50", "mobilenet", "ssd-mobilenet", "ssd-resnet34", "mobilenet-edge", "ssd-mobilenet-v2", "mobilebert","deeplabv3","bert")
PRECISIONS = ("int8", "fp16", "fp32")

PREPROC = {
        "resnet50": "imagenet", 
        "mobilenet": "imagenet",
        "mobilenet-edge": "imagenet",
        "ssd-mobilenet": "coco",
    "ssd-resnet34": "coco",
        "ssd-mobilenet-v2": "coco",
        "mobilebert": "squad",
        "deeplabv3": "ADE20K",
        "bert": "squad"
        }

DATASETS = {
        "resnet50": "dataset-imagenet-ilsvrc2012-val", 
        "mobilenet": "dataset-imagenet-ilsvrc2012-val",
        "mobilenet-edge": "dataset-imagenet-ilsvrc2012-val",
        "ssd-mobilenet": "dataset-coco-2017-val",
        "ssd-resnet34": "dataset-coco-2017-val",
        "ssd-mobilenet-v2": "dataset-coco-2017-val",
        "mobilebert": "dataset-SQUAD",
        "deeplabv3": "ADE20K/images/validation",
        "bert": "dataset-SQUAD"
        }


DEFAULT_CONFIG = {
        "scenario": "Offline",
        "mode": "Performance",
        "model_name": "resnet50",
        "device": "CPU",
        "batch_size": [1],
        "warmup_iters": 50,
        "total_sample_count": 1024, #500,
        "nireq": 8,
        "nthreads": os.cpu_count(),
        "nstreams": 4,
        "nseq": 0,
        "nseq_step": 0,
        "enforcebf16": False
        }


def check_param(key, value, space):

        if value in space:
                return
        else:
                print("'{}' should be one of {}. Provided '{}'".format(key, space, value))
                sys.exit(1)
        

def validate_params(config_data={}):
        params = DEFAULT_CONFIG


        device = config_data.get("device", params["device"]).upper()
        mode = config_data.get("mode", params["mode"])
        scenario = config_data.get("scenario", params["scenario"])
        model_name = config_data.get("model_name", params["model_name"])
        precision = config_data.get("precision", "int8")
        nthreads = config_data.get("threads", os.cpu_count())
        nseq = config_data.get("nseq", 0)
        nseq_step = config_data.get("nseq_step", 0)
        enforce_bf16 = config_data.get("enforcebf16",False)
        total_sample_count = config_data.get("total_sample_count", 1024)


        #check_param("device", device, DEVICES)
        check_param("mode", mode, MODES)
        check_param("scenario", scenario, SCENARIOS)
        check_param("model_name", model_name, MODEL_NAMES)
        check_param("precision", precision, PRECISIONS)
        check_param("enforcebf16", enforce_bf16, [True, False])
        
        params["model_name"] = model_name
        params["mode"] = mode
        params["scenario"] = scenario
        params["device"] = device.upper()
        params["precision"] = precision
        params["nthreads"] = nthreads
        params["nseq"] = nseq
        params["nseq_step"] = nseq_step
        params["total_sample_count"] = total_sample_count
        params["enforcebf16"] = "--enforcebf16" if enforce_bf16 else "--noenforcebf16"

        
        if config_data.get("instances", None):
                params["nireq"] = config_data.get("instances")
        if config_data.get("nthreads", None):
                params["nthreads"] = config_data.get("nthreads")
        if config_data.get("batch_size", None):
                params["batch_size"] = config_data.get("batch_size")
                #print("Batch size: {}".format(params["batch_size"][0]))
        if config_data.get("nstreams", None):
                params["nstreams"] = str(config_data.get("nstreams")).upper()


        # Set other parameters
        params["data_path"] = os.path.join(os.environ["DATA_DIR"],params["model_name"],DATASETS[params["model_name"]])
        params["dataset"] = PREPROC[params["model_name"]]
        params["mlperf_conf"] = os.path.join(os.environ["CONFIGS_DIR"], "mlperf.conf")
        params["user_conf"] = os.path.join(os.environ["CONFIGS_DIR"], params["model_name"], "user.conf")
        params["model_path"] = os.path.join(os.environ["MODELS_DIR"], params["model_name"], params["model_name"]+"_" + precision + ".xml")

        return params


def expand_workloads_to_batch_size_list(params):
        """ Expand batch sizes to count as individual workloads and return """
        
        batch_sizes = params["batch_size"]
        
        if isinstance(batch_sizes, int):
                return [params]
        
        new_params = [{} for j in range(len(batch_sizes))]
        for j in range(len(batch_sizes)):
                new_params[j] = copy.deepcopy(params)
                new_params[j]["batch_size"] = batch_sizes[j]
                
        return new_params
        

def parse_config(config_filename=""):
        """ create dictionary of workloads with ids as keys  and return workload items (config_items) """
        try:
                
                with open(config_filename, 'rb') as fid:
                        config_data = json.load(fid)
                        _nruns = config_data["Iterations"]
                        _run_breaks = config_data["DelayBetweenRuns"]
                        
                        config_items = {}
                        wid = 1
                        for config in config_data["Workloads"]:
                                params = validate_params(config)
                                
                                expanded_params = expand_workloads_to_batch_size_list(params) # Expand batch_sizes to count as individual workloads
                                for w_params in expanded_params:
                                        config_items[wid] = copy.deepcopy(w_params)
                                        wid+= 1
                print("===================================================================")
                print("                 Total number of workload runs: {}                 ".format(_nruns * len(config_items)))
                print("===================================================================")
                return config_items, _nruns, _run_breaks

        except Exception as msg:
                print("Could not read {}: {}".format(config_filename,msg))
                sys.exit(1)

def create_cmd_flags(config_items={}, config_file="", write_commands=True):
        """ Create command flags for each workload the application"""
        workloads_cmd_flags = {}
        
        from datetime import datetime
        _time = datetime.now()
        timestamp = _time.strftime('%m-%d-%y-%H-%M-%S')
        _config_file = os.path.basename(config_file).split(".")[0]
        
        for w_id, params in config_items.items():
                w_details = ""                              # For keeping track of important workload flags
                w_details+= "config_file: " + _config_file + "-" + timestamp + "\n"
                cmd_flags = ""
                
                for param, val in params.items():
                        w_details+= param + ": " + str(val) + "\n"
                        cmd_flags+= "--" + param + " " + str(val) + " "
                
                if write_commands:
                        with open("wid-" + str(w_id) +".txt", "w") as fid:
                                fid.writelines(w_details)
                
                
                workloads_cmd_flags[w_id] = cmd_flags

        return workloads_cmd_flags


def main():
        parser = ArgumentParser()
        parser.add_argument('-c','--config_file', type=str, default="", help="Path to configuration file")
        args = parser.parse_args()

        config_file = os.path.join(os.environ["CONFIGS_DIR"], "default-config.json")
        
        if len(args.config_file):
        
                if os.path.isfile(args.config_file):
                        config_file = args.config_file
                else:
                        print("Could not find config file {}".format(args.config_file))
                        sys.exit(1)
                        
        config_items, _, _ = parse_config(config_file)
        
        # Compose cmd_flags and write to text
        cmd_flags = create_cmd_flags(config_items, config_file)
        with open("cmd_flags.txt", "w") as fid:
                out_txt = "\n".join(line for line in cmd_flags.values())
                fid.writelines(out_txt)


if __name__=="__main__":
        main()
