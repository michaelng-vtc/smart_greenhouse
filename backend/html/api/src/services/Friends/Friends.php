<?php

namespace App\Services\Friends;

use PDO;

class Friends
{
    private $db;

    public function __construct(PDO $db)
    {
        $this->db = $db;
    }

    public function addFriend($userId, $friendUsername)
    {
        // Find friend ID by username
        $stmt = $this->db->prepare("SELECT id FROM users WHERE username = :username");
        $stmt->execute([':username' => $friendUsername]);
        $friend = $stmt->fetch(PDO::FETCH_ASSOC);

        if (!$friend) {
            return ['error' => 'User not found'];
        }

        $friendId = $friend['id'];

        if ($userId == $friendId) {
            return ['error' => 'Cannot add yourself'];
        }

        // Check if already friends or pending (check both directions)
        $stmt = $this->db->prepare("SELECT * FROM friends WHERE (user_id = :uid AND friend_id = :fid) OR (user_id = :fid AND friend_id = :uid)");
        $stmt->execute([':uid' => $userId, ':fid' => $friendId]);
        if ($stmt->fetch()) {
            return ['error' => 'Friend request already exists or already friends'];
        }

        // Insert request
        $stmt = $this->db->prepare("INSERT INTO friends (user_id, friend_id, status) VALUES (:uid, :fid, 'pending')");
        if ($stmt->execute([':uid' => $userId, ':fid' => $friendId])) {
            return ['message' => 'Friend request sent'];
        }

        return ['error' => 'Failed to send request'];
    }

    public function getFriends($userId)
    {
        // Get accepted friends
        $sql = "
            SELECT u.id, u.username 
            FROM users u
            JOIN friends f ON (u.id = f.friend_id AND f.user_id = :uid) OR (u.id = f.user_id AND f.friend_id = :uid)
            WHERE f.status = 'accepted'
        ";
        $stmt = $this->db->prepare($sql);
        $stmt->execute([':uid' => $userId]);
        return $stmt->fetchAll(PDO::FETCH_ASSOC);
    }

    public function getPendingRequests($userId)
    {
        // Requests sent TO me
        $sql = "
            SELECT u.id, u.username, f.id as request_id
            FROM users u
            JOIN friends f ON u.id = f.user_id
            WHERE f.friend_id = :uid AND f.status = 'pending'
        ";
        $stmt = $this->db->prepare($sql);
        $stmt->execute([':uid' => $userId]);
        return $stmt->fetchAll(PDO::FETCH_ASSOC);
    }

    public function acceptRequest($userId, $requestId)
    {
        // Verify the request is for this user
        $stmt = $this->db->prepare("UPDATE friends SET status = 'accepted' WHERE id = :rid AND friend_id = :uid");
        if ($stmt->execute([':rid' => $requestId, ':uid' => $userId])) {
            if ($stmt->rowCount() > 0) {
                return ['message' => 'Friend request accepted'];
            } else {
                return ['error' => 'Request not found or already accepted'];
            }
        }
        return ['error' => 'Failed to accept request'];
    }
}
