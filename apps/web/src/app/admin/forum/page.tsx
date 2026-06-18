import { ForumFeed } from "@/components/forum/forum-feed"
import { ModerationDashboard } from "@/components/admin/moderation-dashboard"
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs"

export default async function AdminForumFeedPage({
    searchParams,
}: {
    searchParams: Promise<{ category?: string }>
}) {
    const params = await searchParams
    return (
        <div className="space-y-8">
            <Tabs defaultValue="feed">
                <TabsList className="bg-muted px-4 py-6 rounded-2xl border border-muted-foreground/10 overflow-x-auto flex justify-start gap-4">
                    <TabsTrigger value="feed" className="px-6 rounded-full font-bold">Community Feed</TabsTrigger>
                    <TabsTrigger value="moderation" className="px-6 rounded-full font-bold">Moderation Queue</TabsTrigger>
                </TabsList>
                
                <TabsContent value="feed">
                    <ForumFeed category={params.category} role="admin" />
                </TabsContent>
                
                <TabsContent value="moderation">
                    <ModerationDashboard />
                </TabsContent>
            </Tabs>
        </div>
    )
}
