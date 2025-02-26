
import ray
import os
from ray.util import ActorPool
from service_pb2_grpc import LoadTestServiceStub
from request_pb2 import LoadTask
from apache_beam.utils.subprocess_server import SubprocessServer


@ray.remote(num_cpus=1)
class DoStuff:

    # The quant library can be loaded from anywhere (parallelstore, GCS, etc)
    def __init__(self):

        # ugly hack as permissions when copied do not include execute.
        # gcsfuse also doesn't include execute permissions.
        os.chmod("./loadtest", 0o555)

        self.stub = SubprocessServer(
            LoadTestServiceStub, ["./loadtest", "serve", "--port", "{{PORT}}"]
        ).__enter__()

    def __del__(self):
        print('Shutting down Actor.')
        self.stub.__exit__()

    # This can also load data from GCS, etc, etc
    def run_task(self, min_micros=100_000, max_micros=100_000) -> float:
        result = self.stub.RunLibrary(LoadTask(
            task=LoadTask.Task(
                min_micros=min_micros,
                max_micros=max_micros,
            ),
        ))
        return result.task.compute_micros


ray.init()

# 10 workers
pool = ActorPool([DoStuff.remote() for _ in range(20)])

# dispatch the work
gen = pool.map(lambda w, _: w.run_task.remote(1_500_000, 2_000_000), range(500))

# collect the work and print results
print(list(gen))

ray.shutdown()
