import requests
import unittest
import subprocess
import time
import os

class TestAPI(unittest.TestCase):

    def get_external_ip_eks(self):
        """
        Get the external IP or DNS of the service.
        """        
        cmd = ["kubectl", "get", "svc", "message-api", "-n", "message-api", "-o", "jsonpath='{.status.loadBalancer.ingress[0].hostname}'"]
        external_ip = subprocess.check_output(cmd).decode('utf-8').strip().strip("'")
        return external_ip


    def wait_for_service(self, max_retries=10, delay=5):
        """
        Wait for the service to be available and return the response JSON.
        """
        url = f"http://{self.get_external_ip_eks()}/api/message"

        for _ in range(max_retries):
            try:
                response = requests.get(url)
                if response.status_code == 200:
                    return response.json()
            except requests.RequestException:
                time.sleep(delay)

        raise Exception("Service is not available after multiple retries.")

    def test_message_api(self):
        data = self.wait_for_service()

        self.assertEqual(data['message'], "Automate all the things!")
        self.assertIsInstance(data['timestamp'], int)

if __name__ == "__main__":
    unittest.main()
