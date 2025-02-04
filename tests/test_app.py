import pytest
from app.main import app

@pytest.fixture
def client():
    """Fixture qui crée un client de test Flask."""
    with app.test_client() as client:
        yield client

def test_home(client):
    """Test : Vérifie que l’endpoint '/' retourne le bon message."""
    response = client.get('/')
    assert response.status_code == 200
    assert response.json == {"message": "Hello from Flask in Kubernetes with Argo!"}

