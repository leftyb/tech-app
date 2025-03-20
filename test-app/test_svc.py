import subprocess
import unittest
import time
import json
import os

class TestAPI(unittest.TestCase):

    def wait_for_service(self, max_retries=10, delay=5):
        """
        Wait for the service to be available by using kubectl exec to call the service.
        This simulates the behavior of `kubectl exec svc/message-api`.
        """
        namespace = "message-api" 
        service_name = "message-api"
        for _ in range(max_retries):
            try:
                # Run curl inside the service using kubectl exec
                cmd = [
                    "kubectl", "exec", "-n", namespace, "svc/" + service_name,
                    "--", "curl", "-s", "http://message-api:80/api/message"
                ]
                response = subprocess.check_output(cmd).decode('utf-8').strip()
                if response:
                    return response
            except subprocess.CalledProcessError:                
                time.sleep(delay)
        raise Exception("Service is not available after multiple retries.")

    def test_message_api(self):
        response = self.wait_for_service()
        data = json.loads(response)

        # Test the response content
        self.assertEqual(data['message'], "Automate all the things!")
        self.assertIsInstance(data['timestamp'], int)

if __name__ == "__main__":
    unittest.main()
